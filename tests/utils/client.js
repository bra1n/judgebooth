const axios = require('axios');
const axiosCookieJarSupport = require('axios-cookiejar-support').default;
const tough = require('tough-cookie');

axiosCookieJarSupport(axios);
const cookieJar = new tough.CookieJar();

const instance = axios.create({
    baseURL: process.env.BACKEND_URL || 'http://localhost:8080/backend',
    timeout: 1000,
    jar: cookieJar,
    withCredentials: true,
});

module.exports = instance;