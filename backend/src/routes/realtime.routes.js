const express = require('express');
const pool = require('../db');

const router = express.Router();
let schemaReady;

function asyncRoute(handler) {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}

async function ensureRealtimeSchema() {
  if (!schemaReady) {
    schemaReady = (async () => {
      await pool.execute(`
        CREATE TABLE IF NOT EXISTS iot_devices (
          id INT AUTO_INCREMENT PRIMARY KEY,
          project_id INT NULL,
          microcontroller_id INT NULL,
          hardware_id VARCHAR(120) NOT NULL,
          device_name VARCHAR(255),
          ip_address VARCHAR(45) NOT NULL,
          mac_address VARCHAR(50),
          firmware_version VARCHAR(80),
          last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          UNIQUE KEY uniq_hardware_id (hardware_id),
          KEY idx_iot_devices_ip (ip_address)
        )
      `);

      await pool.execute(`
        CREATE TABLE IF NOT EXISTS sensor_readings (
          id BIGINT AUTO_INCREMENT PRIMARY KEY,
          device_id INT NOT NULL,
          project_id INT NULL,
          hardware_id VARCHAR(120) NOT NULL,
          ip_address VARCHAR(45) NOT NULL,
          sensor_type VARCHAR(120),
          readings JSON NOT NULL,
          raw_payload JSON,
          recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          KEY idx_sensor_readings_device_time (device_id, recorded_at),
          KEY idx_sensor_readings_ip_time (ip_address, recorded_at),
          KEY idx_sensor_readings_hardware_time (hardware_id, recorded_at)
        )
      `);
    })();
  }

  return schemaReady;
}

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  const rawIp = Array.isArray(forwarded)
    ? forwarded[0]
    : (forwarded || req.socket.remoteAddress || '');

  return rawIp.split(',')[0].trim().replace(/^::ffff:/, '');
}

function normalizeReadings(body) {
  if (!body || typeof body !== 'object') {
    return {};
  }

  if (typeof body.readings === 'string' && body.readings.trim().startsWith('{')) {
    try {
      return JSON.parse(body.readings);
    } catch (_error) {
      return {};
    }
  }

  if (body.readings && typeof body.readings === 'object' && !Array.isArray(body.readings)) {
    return body.readings;
  }

  const readings = {};
  const reserved = new Set([
    'project_id',
    'microcontroller_id',
    'hardware_id',
    'device_name',
    'ip_address',
    'mac_address',
    'firmware_version',
    'sensor_type',
    'readings',
    'recorded_at',
  ]);

  Object.entries(body).forEach(([key, value]) => {
    if (!reserved.has(key) && typeof value !== 'object') {
      readings[key] = value;
    }
  });

  return readings;
}

function validatePayload(body) {
  const readings = normalizeReadings(body);
  if (!Object.keys(readings).length) {
    return 'readings must contain at least one value';
  }

  return null;
}

async function saveReading(req, res) {
  await ensureRealtimeSchema();

  const validationError = validatePayload(req.body);
  if (validationError) {
    return res.status(400).json({ message: validationError });
  }

  const {
    project_id,
    microcontroller_id,
    hardware_id,
    device_name,
    mac_address,
    firmware_version,
    sensor_type,
    recorded_at,
  } = req.body;
  const ipAddress = req.body.ip_address || getClientIp(req);
  const resolvedHardwareId = hardware_id || `ip:${ipAddress}`;
  const readings = normalizeReadings(req.body);
  const projectId = Number.isFinite(Number(project_id)) ? Number(project_id) : null;
  const microcontrollerId = Number.isFinite(Number(microcontroller_id))
    ? Number(microcontroller_id)
    : null;

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    await connection.execute(
      `INSERT INTO iot_devices
        (project_id, microcontroller_id, hardware_id, device_name, ip_address, mac_address, firmware_version, last_seen_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
       ON DUPLICATE KEY UPDATE
        project_id = COALESCE(VALUES(project_id), project_id),
        microcontroller_id = COALESCE(VALUES(microcontroller_id), microcontroller_id),
        device_name = COALESCE(VALUES(device_name), device_name),
        ip_address = VALUES(ip_address),
        mac_address = COALESCE(VALUES(mac_address), mac_address),
        firmware_version = COALESCE(VALUES(firmware_version), firmware_version),
        last_seen_at = NOW()`,
      [
        projectId,
        microcontrollerId,
        resolvedHardwareId,
        device_name || null,
        ipAddress,
        mac_address || null,
        firmware_version || null,
      ]
    );

    const [devices] = await connection.execute(
      'SELECT id FROM iot_devices WHERE hardware_id = ? LIMIT 1',
      [resolvedHardwareId]
    );
    const deviceId = devices[0].id;

    const [result] = await connection.execute(
      `INSERT INTO sensor_readings
        (device_id, project_id, hardware_id, ip_address, sensor_type, readings, raw_payload, recorded_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, COALESCE(?, NOW()))`,
      [
        deviceId,
        projectId,
        resolvedHardwareId,
        ipAddress,
        sensor_type || null,
        JSON.stringify(readings),
        JSON.stringify(req.body),
        recorded_at || null,
      ]
    );

    await connection.commit();

    const savedReading = {
      id: result.insertId,
      device_id: deviceId,
      project_id: projectId,
      hardware_id: resolvedHardwareId,
      ip_address: ipAddress,
      sensor_type: sensor_type || null,
      readings,
      recorded_at: recorded_at || new Date().toISOString(),
    };

    req.app.get('io')?.emit('sensor:reading', savedReading);

    return res.status(201).json({
      message: 'Reading saved',
      data: savedReading,
    });
  } catch (error) {
    await connection.rollback();
    console.error('Unable to save sensor reading:', error);
    return res.status(500).json({
      message: 'Unable to save sensor reading',
      error: error.message,
    });
  } finally {
    connection.release();
  }
}

router.post('/readings', asyncRoute(saveReading));
router.post('/data', asyncRoute(saveReading));

router.get('/readings', asyncRoute(async (req, res) => {
  await ensureRealtimeSchema();

  const limit = Math.min(Number(req.query.limit || 100), 500);
  const filters = [];
  const values = [];

  if (req.query.ip_address) {
    filters.push('sr.ip_address = ?');
    values.push(req.query.ip_address);
  }

  if (req.query.hardware_id) {
    filters.push('sr.hardware_id = ?');
    values.push(req.query.hardware_id);
  }

  if (req.query.project_id) {
    filters.push('sr.project_id = ?');
    values.push(req.query.project_id);
  }

  const whereClause = filters.length ? `WHERE ${filters.join(' AND ')}` : '';

  try {
    const [rows] = await pool.execute(
      `SELECT
        sr.id,
        sr.device_id,
        sr.project_id,
        sr.hardware_id,
        sr.ip_address,
        sr.sensor_type,
        sr.readings,
        sr.recorded_at,
        d.device_name,
        d.mac_address,
        d.firmware_version
       FROM sensor_readings sr
       JOIN iot_devices d ON d.id = sr.device_id
       ${whereClause}
       ORDER BY sr.recorded_at DESC, sr.id DESC
       LIMIT ${limit}`,
      values
    );

    return res.status(200).json(rows);
  } catch (error) {
    console.error('Unable to fetch sensor readings:', error);
    return res.status(500).json({
      message: 'Unable to fetch sensor readings',
      error: error.message,
    });
  }
}));

router.get('/devices', asyncRoute(async (_req, res) => {
  await ensureRealtimeSchema();

  try {
    const [rows] = await pool.execute(
      `SELECT
        d.*,
        (
          SELECT sr.readings
          FROM sensor_readings sr
          WHERE sr.device_id = d.id
          ORDER BY sr.recorded_at DESC, sr.id DESC
          LIMIT 1
        ) AS latest_readings
       FROM iot_devices d
       ORDER BY d.last_seen_at DESC`
    );

    return res.status(200).json(rows);
  } catch (error) {
    console.error('Unable to fetch IoT devices:', error);
    return res.status(500).json({
      message: 'Unable to fetch IoT devices',
      error: error.message,
    });
  }
}));

router.use((error, _req, res, _next) => {
  console.error('Realtime route failed:', error);
  res.status(500).json({
    message: 'Realtime backend error',
    error: error.message,
  });
});

module.exports = router;
