const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const source = fs.readFileSync(__dirname + '/flow-ui.js', 'utf8');
const pick = name => source.split('\n').find(line => line.startsWith(`function ${name}(`));
const grouped = source.slice(source.indexOf('orderLines=(o,opts={})=>'), source.indexOf('// Authoritative commands'));
const context = {
  options: {onServe(){}},snapshot:{me:{role:'waiter'}},
  ST: {lang: 'ru'},
  M: {food: {st: 'k', p: 95000}, drink: {st: 'b', p: 35000}},
  t: key => ({kKitchen: 'Кухня', kBar: 'Бар'})[key],
  esc: value => String(value),
  nm: (id, lang) => ({food: {vi: 'Bánh pie bắp cải', ru: 'Пирог с капустой'}, drink: {vi: 'Sài Gòn Special', ru: 'Сайгон Спешл'}}[id])[lang],
  vnd: value => String(value),
};
context.stationItems = (order, scope) => order.items.filter(item => context.M[item.mid].st === (scope === 'bar' ? 'b' : 'k'));
context.stationReady = (order, scope) => {
  const items = context.stationItems(order, scope);
  return items.length > 0 && items.every(item => item.done);
};
vm.createContext(context);
vm.runInContext(['let orderLines;', grouped, pick('serveActions'), 'this.lines = orderLines; this.actions = serveActions'].join('\n'), context);

const order = {id: 'order-1', waiter:'me',status: 'cooking', lang: 'vi', stationServedAt: {}, items: [
  {mid: 'food', qty: 1, done: false},
  {mid: 'drink', qty: 1, done: true},
]};
const html = context.lines(order);
assert.match(html, /is-cooking[\s\S]*Кухня[\s\S]*Готовится[\s\S]*Bánh pie bắp cải/);
assert.match(html, /is-ready[\s\S]*Бар[\s\S]*Можно вынести[\s\S]*Sài Gòn Special/);
assert.match(context.actions(order), /data-scope="bar"[\s\S]*Бар: вынесено/);
assert.doesNotMatch(context.actions(order), /data-scope="kitchen"/);
context.ST.me='me';
assert.match(context.lines(order),/data-waiter-serve="order-1" data-station="kitchen"/);
assert.match(context.lines(order),/data-waiter-serve="order-1" data-station="bar"/);assert.match(context.lines(order),/Вынес/);assert.doesNotMatch(context.lines(order),/Кухня: готово|Бар: готово/);
context.ST.me='other';assert.doesNotMatch(context.lines(order),/data-waiter-serve/);
console.log('PASS ready bar items are separated from cooking kitchen items');
