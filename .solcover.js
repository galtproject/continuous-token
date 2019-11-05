module.exports = {
    testrpcOptions: '-p 8555 -e 500000000 -a 35 -v',

    skipFiles: [
        'Migrations.sol',
        'vendor',
        'mocks',
    ],
    compileCommand: '../node_modules/.bin/truffle compile',
};
