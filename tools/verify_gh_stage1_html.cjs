const fs = require('fs');
const path = require('path');
const {pathToFileURL} = require('url');
const {chromium} = require('playwright');
const root = path.resolve(__dirname,'..');
const out = path.join(root,'analysis_output/logic_recovery');
(async () => {
  const browser = await chromium.launch({headless:true});
  const results = [];
  for (const [name,width,height] of [['desktop',1440,1000],['mobile',390,844]]) {
    const page = await browser.newPage({viewport:{width,height}});
    const errors = [];
    page.on('pageerror',e=>errors.push(String(e)));
    await page.goto(pathToFileURL(path.join(out,'stage1_inventory.html')).href);
    const stats = await page.locator('#stats').innerText();
    if (!stats.includes('3,415') || !stats.includes('43,784')) throw Error('Stale headline counts');
    if (!(await page.locator('#overview').innerText()).includes('318')) throw Error('Missing dependency boundary');
    await page.screenshot({path:path.join(out,`stage1-${name}.png`),fullPage:true});
    const overflow = await page.evaluate(()=>document.documentElement.scrollWidth > innerWidth);
    await page.locator('[data-tab=modules]').click();
    await page.locator('#search').fill('RandomGenerateCodeHelper');
    const count = await page.locator('#resultCount').innerText();
    if (!count.startsWith('2 ')) throw Error('Lost packaged/hotfix module variants');
    await page.locator('#validationFilter').selectOption('compiled_structure_differs');
    if (!(await page.locator('#resultCount').innerText()).startsWith('0 ')) throw Error('Stale Lua mismatch rows');
    await page.locator('[data-tab=issues]').click();
    if (await page.locator('#issueRows details').count() !== 4) throw Error('Issue denominator differs');
    results.push({name,width,height,errors,overflow,variant_filter_count:count});
    if (errors.length || overflow) throw Error(JSON.stringify(results));
    await page.close();
  }
  await browser.close();
  fs.writeFileSync(path.join(out,'html_verification.json'),JSON.stringify(results,null,2));
  console.log(results);
})().catch(e=>{console.error(e);process.exitCode=1;});
