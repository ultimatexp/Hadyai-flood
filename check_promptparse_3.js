const { generate } = require('promptparse');
console.log(typeof generate.anyId);
try {
    const payload = generate.anyId('0812345678', { amount: 100 });
    console.log('Payload:', payload);
} catch (e) {
    console.error(e);
}
