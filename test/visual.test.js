require('dotenv').config();
const { expect } = require('chai');
const { By, until } = require('selenium-webdriver');
const { buildDriver } = require('../utils/driver');
const { URLS } = require('../config/urls');

describe('Demo Site - Page Smoke Tests', function () {
  let driver;

  before(async function () {
    driver = await buildDriver();
  });

  after(async function () {
    if (driver) await driver.quit();
  });

  it('login page loads with a title', async function () {
    await driver.get(URLS.login);
    await driver.wait(until.elementLocated(By.css('#username')), 15000);
    expect(await driver.getTitle()).to.not.be.empty;
  });

  it('app page loads after login', async function () {
    await driver.get(URLS.app);
    expect(await driver.getTitle()).to.not.be.empty;
  });

  it('home page loads with a title', async function () {
    await driver.get(URLS.home);
    expect(await driver.getTitle()).to.not.be.empty;
  });

  it('mobile emulation page loads', async function () {
    await driver.get(URLS.mobile);
    expect(await driver.getTitle()).to.not.be.empty;
  });
});

