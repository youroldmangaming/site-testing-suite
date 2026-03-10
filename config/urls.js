const DEMO_URL  = 'https://demo.applitools.com';
const PAGES_URL = 'https://applitools.github.io/demo';

const URLS = {
  login:  DEMO_URL,
  app:    `${DEMO_URL}/app.html`,
  home:   `${PAGES_URL}/`,
  mobile: `${PAGES_URL}/MobileEmulation/index.html`,
};

const LOGIN = {
  username: '#username',
  password: '#password',
  loginBtn: '#log-in',     // <a> tag — always navigates to app.html
};

module.exports = { URLS, LOGIN };
