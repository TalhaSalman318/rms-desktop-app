const dns = require('node:dns');
const mongoose = require('mongoose');

const connectDatabase = async () => {
  try {
    const dnsServers = (process.env.DNS_SERVERS || '1.1.1.1,8.8.8.8')
      .split(',')
      .map((server) => server.trim())
      .filter(Boolean);
    dns.setServers(dnsServers);

    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB Atlas connected successfully!');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    throw error;
  }
};

module.exports = connectDatabase;