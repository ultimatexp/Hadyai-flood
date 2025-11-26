const { generate } = require('promptparse');
try {
    // 0812345678 is a standard Thai mobile number
    const payload = generate.trueMoney('0812345678', { amount: 100 });
    console.log('Payload:', payload);
} catch (e) {
    console.error(e);
}
