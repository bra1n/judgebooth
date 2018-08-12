const axios = require('axios');
const instance = axios.create({
    baseURL: 'http://localhost:8080/backend',
    timeout: 1000,
});

test('snapshot /?action=sets', async () => {
    const response = await instance.get('/?action=sets');
    expect(response.data).toMatchSnapshot();
});

test('snapshot /?action=questions', async () => {
    const response = await instance.get('/?action=questions');
    expect(response.data).toMatchSnapshot();
});

test('snapshot /?action=question&id=-2', async () => {
    // TODO: probably we should return 404
    const response = await instance.get('/?action=question&id=-2');
    expect(response.data).toMatchSnapshot();
});

test('snapshot /?action=question&id=58', async () => {
    const response = await instance.get('/?action=question&id=58');
    expect(response.data).toMatchSnapshot();
});

test('snapshot /?action=question&id=58&lang=1', async () => {
    const response = await instance.get('/?action=question&id=58&lang=1');
    expect(response.data).toMatchSnapshot();
});

test('snapshot /?action=offline', async () => {
    const response = await instance.get('/?action=offline');
    expect(response.data).toMatchSnapshot();
});