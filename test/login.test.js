require('dotenv').config();
const { expect } = require('chai');
const { By, until } = require('selenium-webdriver');
const { buildDriver } = require('../utils/driver');
const { URLS, LOGIN } = require('../config/urls');

// Driver is shared across tests in this suite to avoid renderer timeouts
// from spinning up too many Chrome/Edge sessions back-to-back.
describe('Login Page', function () {
  let driver;

  before(async function () {
    driver = await buildDriver();
    await driver.get(URLS.login);
    await driver.wait(until.elementLocated(By.css(LOGIN.loginBtn)), 15000);
  });

  after(async function () {
    if (driver) await driver.quit();
  });

  it('renders the username field', async function () {
    expect(await driver.findElement(By.css(LOGIN.username)).isDisplayed()).to.be.true;
  });

  it('renders the password field', async function () {
    expect(await driver.findElement(By.css(LOGIN.password)).isDisplayed()).to.be.true;
  });

  it('renders the login button', async function () {
    const btn = await driver.findElement(By.css(LOGIN.loginBtn));
    expect(await btn.isDisplayed()).to.be.true;
  });

  it('accepts input in username and password fields', async function () {
    await driver.findElement(By.css(LOGIN.username)).sendKeys('admin');
    await driver.findElement(By.css(LOGIN.password)).sendKeys('password123');
    expect(await driver.findElement(By.css(LOGIN.username)).getAttribute('value')).to.equal('admin');
    expect(await driver.findElement(By.css(LOGIN.password)).getAttribute('value')).to.equal('password123');
  });

  it('clears fields after clearing input', async function () {
    const field = await driver.findElement(By.css(LOGIN.username));
    await field.clear();
    await field.sendKeys('testuser');
    await field.clear();
    expect(await field.getAttribute('value')).to.equal('');
  });

  it('login button navigates to the app page', async function () {
    await driver.findElement(By.css(LOGIN.username)).sendKeys('admin');
    await driver.findElement(By.css(LOGIN.password)).sendKeys('admin');
    await driver.findElement(By.css(LOGIN.loginBtn)).click();
    await driver.wait(until.urlContains('app'), 10000);
    expect(await driver.getCurrentUrl()).to.include('app');
  });
});

