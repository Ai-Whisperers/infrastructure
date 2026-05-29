const http = require('http');

// Test if the dashboard is accessible
function testDashboard() {
    console.log('Testing dashboard accessibility...');

    // Test the main HTML page
    const options = {
        hostname: 'localhost',
        port: 3001,
        path: '/index.html',
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        console.log(`HTML Status: ${res.statusCode}`);

        if (res.statusCode === 200) {
            console.log('✅ Dashboard HTML is accessible');
        } else {
            console.log('❌ Dashboard HTML failed to load');
        }

        // Test API endpoint
        testAPI();
    });

    req.on('error', (err) => {
        console.log('❌ Dashboard server is not running:', err.message);
        console.log('💡 Try starting the server with: npm start');
    });

    req.end();
}

function testAPI() {
    const options = {
        hostname: 'localhost',
        port: 3001,
        path: '/api/projects',
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        console.log(`API Status: ${res.statusCode}`);

        let data = '';
        res.on('data', (chunk) => {
            data += chunk;
        });

        res.on('end', () => {
            if (res.statusCode === 200) {
                console.log('✅ Dashboard API is accessible');
                try {
                    const parsed = JSON.parse(data);
                    console.log(`📊 Found ${parsed.projects ? parsed.projects.length : 0} projects`);
                } catch (e) {
                    console.log('⚠️ API response is not valid JSON');
                }
            } else {
                console.log('❌ Dashboard API failed to respond');
            }
        });
    });

    req.on('error', (err) => {
        console.log('❌ Dashboard API is not accessible:', err.message);
    });

    req.end();
}

// Run the test
testDashboard();