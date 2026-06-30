// In-memory project store (mirrors the rows in database/schema.sql).
// githubRepoUrl is mutable at runtime via the /github/connect endpoint.
const projects = [
  { id: 1, name: 'Criminal Activity Detector and Monitoring System (CADMS)', githubRepoUrl: null },
  { id: 2, name: 'SmartHome (SH)', githubRepoUrl: null },
  { id: 3, name: 'Smart Traffic Controll and Monitoring System (STCMS)', githubRepoUrl: null },
  { id: 4, name: 'Drone Controller (DC)', githubRepoUrl: null },
  { id: 5, name: 'Bahan Kavach (BK)', githubRepoUrl: null },
  { id: 6, name: 'Blind Curve Monitoring System (BCMS)', githubRepoUrl: null },
  { id: 7, name: 'Wild Animal Monitoring System (WAMS)', githubRepoUrl: null },
  { id: 8, name: 'CommStick (CS)', githubRepoUrl: null },
  { id: 9, name: 'High Speed Data Transmitter (HSDT, FSO)', githubRepoUrl: null },
  { id: 10, name: 'Smart Healthcare Monitoring (SHCM)', githubRepoUrl: null },
  { id: 11, name: 'Water Quality Monitoring System (WQMS)', githubRepoUrl: null },
  { id: 12, name: 'Weather Monitoring System (WMS)', githubRepoUrl: null },
  { id: 13, name: 'Soil Quality Monitoring System (SQM)', githubRepoUrl: null },
  { id: 14, name: 'Indoor Pollution Monitoring System (IPMS)', githubRepoUrl: null },
  { id: 15, name: 'Underground Pollution Monitoring System (UPMS)', githubRepoUrl: null },
  { id: 16, name: 'Outdoor Pollution Monitoring System (OPMS)', githubRepoUrl: null },
  { id: 17, name: 'All in one IoT Monitoring System (AIoTMS)', githubRepoUrl: null },
  { id: 18, name: 'All in one Energy Monitoring System (AMS)', githubRepoUrl: null },
];

function findById(id) {
  return projects.find((p) => p.id === Number(id));
}

module.exports = { projects, findById };
