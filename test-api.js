const fs = require('fs');

async function testApi() {
    const fetch = (await import('node-fetch')).default;
    const FormData = (await import('form-data')).default;

    const form = new FormData();
    form.append('image', fs.createReadStream('./public/test_dog.jpg'));

    try {
        const response = await fetch('http://localhost:3000/api/analyze-social-post', {
            method: 'POST',
            body: form
        });

        const text = await response.text();
        console.log("Status:", response.status);
        console.log("Response:", text);
    } catch (error) {
        console.error("Error:", error);
    }
}

testApi();
