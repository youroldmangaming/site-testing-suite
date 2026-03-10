require('dotenv').config();
const { expect } = require('chai');
const { By, until } = require('selenium-webdriver');
const { buildDriver } = require('../utils/driver');
const { URLS, LOGIN } = require('../config/urls');

const BROWSERS = ['chrome', 'edge'];

BROWSERS.forEach((browser) => {
  describe(`[${browser.toUpperCase()}] Login Page`, function () {
    let driver;

    before(async function () {
      driver = await buildDriver(browser);
      await driver.get(URLS.login);
      await driver.wait(until.elementLocated(By.css(LOGIN.loginBtn)), 15000);
    });

    after(async function () {
      if (driver) await driver.quit();
    });

    it('renders login form elements', async function () {
      expect(await driver.findElement(By.css(LOGIN.username)).isDisplayed()).to.be.true;
      expect(await driver.findElement(By.css(LOGIN.password)).isDisplayed()).to.be.true;
      expect(await driver.findElement(By.css(LOGIN.loginBtn)).isDisplayed()).to.be.true;
    });

    it('accepts typed credentials', async function () {
      await driver.findElement(By.css(LOGIN.username)).sendKeys('admin');
      await driver.findElement(By.css(LOGIN.password)).sendKeys('secret');
      expect(
        await driver.findElement(By.css(LOGIN.username)).getAttribute('value')
      ).to.equal('admin');
    });

    it('login button navigates to app page', async function () {
      await driver.findElement(By.css(LOGIN.username)).clear();
      await driver.findElement(By.css(LOGIN.username)).sendKeys('admin');
      await driver.findElement(By.css(LOGIN.password)).sendKeys('admin');
      await driver.findElement(By.css(LOGIN.loginBtn)).click();
      await driver.wait(until.urlContains('app'), 10000);
      expect(await driver.getCurrentUrl()).to.include('app');
    });
  });

  describe(`[${browser.toUpperCase()}] Page Smoke Tests`, function () {
    let driver;

    before(async function () {
      driver = await buildDriver(browser);
    });

    after(async function () {
      if (driver) await driver.quit();
    });

    it('home page has a title', async function () {
      await driver.get(URLS.home);
      expect(await driver.getTitle()).to.not.be.empty;
    });

    it('mobile page loads', async function () {
      await driver.get(URLS.mobile);
      expect(await driver.getTitle()).to.not.be.empty;
    });
  });
});


