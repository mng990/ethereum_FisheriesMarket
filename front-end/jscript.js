const express = require('express')
const app = express()
const port = 3000
const Web3 = require('web3');
var options = {
    timeout: 30000, // ms

    clientConfig: {
        // Useful if requests are large
        maxReceivedFrameSize: 100000000,   // bytes - default: 1MiB
        maxReceivedMessageSize: 100000000, // bytes - default: 8MiB

        // Useful to keep a connection alive
        keepalive: true,
        keepaliveInterval: 60000 // ms
    },

    // Enable auto reconnection
    reconnect: {
        auto: true,
        delay: 5000, // ms
        maxAttempts: 5,
        onTimeout: false
    }
};

app.use(express.static('public'))

app.get('/', (req, res) => res.send('Hello World!', options))
 
// app.get('/Path1', (req, res) => res.send('Get Path1'))
// app.get('/Path2', (req, res) => res.send('Get Path2'))
// app.put('/Path1', (req, res) => res.send('PUT Path1'))

//지금은 이부분만
function getWeb3() { 
    const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));
    return web3;
}

async function getAccounts() {

    try {
        const web3 = new Web3(module.w_eth);
        let accounts = await web3.eth.getAccounts(); 

        console.log(accounts[0]);
        console.log(web3.eth.getBalance(accounts[0]))

        //contract 가져오기
        let CA = "0xA69ae9502cEfdA067cDcc9b704aCb09138520d1c";
        let studentJSON = require("./AuctionContract.json");
        let ABI = studentJSON.abi;
        let Auction = new web3.eth.Contract(ABI, CA);

        console.log("contract 가져오기");
        let pot = await Auction.methods.getBidsCount(2).call();
        console.log(pot)

        // //경매 등록
        let auction = await Auction.methods.createAuction("1",2000,22222).send({from:accounts[0],value:0,gas:0});
        
        // //경매 등록된 아이디
        //let bid =  await Auction.methods.getAuctionsOf(accounts[0]).call();

        // //1번 아이디 경매 정보
        let data = await Auction.methods.getAuctionById(1).call();

        console.log(auction)
        //console.log(data[0])
        console.log(data)
        //console.log("아이디",bid)

    } catch (e) {
        console.log(e);
    }
}


app.get('/total_lib', function(req, res) {
    var word = req.query.word;
    // var request = require('request');
    // var options = {
    // 'method': 'GET',
    // 'url': 'http://apis.data.go.kr/6260000/BusanLibraryInfoService/getLibraryInfo?serviceKey=4NcrAr4OjUAlIMI6hEZ0aodkuOqAm8YWJUmnHU94JZPIKGG8CTFAmfY212NLrwk%2B%2BzAGvQHLfxR9nlvi0rcBjA%3D%3D&numOfRows=10000&resultType=json&' + encodeURI(word),
    // 'headers': {
    //     'Cookie': 'JSESSIONID=Oou1zEasxLBBYOXkPt8GTV8Q0c0QmPta0Ic5aSVxcq916au17prdyC5C0U1Mvvm8.amV1c19kb21haW4vbmV3c2t5Mw=='
    // }
    // };
    // request(options, function (error, response) {
    //     if (error) throw new Error(error);
    //         console.log(response.body);
    //         res.send(response.body);
    // });

    console.log("hello");
    getAccounts();
    // var request = require('request');
    // var options = {
    // 'method': 'GET',
    // 'url': 'http://apis.data.go.kr/6260000/BusanLibraryInfoService/getLibraryInfo?serviceKey=4NcrAr4OjUAlIMI6hEZ0aodkuOqAm8YWJUmnHU94JZPIKGG8CTFAmfY212NLrwk%2B%2BzAGvQHLfxR9nlvi0rcBjA%3D%3D&numOfRows=10000&resultType=json',
    // 'headers': {
    //     'Cookie': 'JSESSIONID=Oou1zEasxLBBYOXkPt8GTV8Q0c0QmPta0Ic5aSVxcq916au17prdyC5C0U1Mvvm8.amV1c19kb21haW4vbmV3c2t5Mw=='
    // }
    // };
    // request(options, function (error, response) {
    //     if (error) throw new Error(error);
    //         console.log(response.body);
    //         res.send(response.body);
    // });
	// const fs = require('fs');
	// const contractABI = JSON.parse(fs.readFileSync('./public/ooo/AuctionContract.json')).abi;
	// console.log(contractABI)

	// const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));
	// const accounts = await web3.eth.getAccounts();
	// console.log(accounts);

})

app.get('/search_gu_lib', function(req, res) {
    var word = req.query.word;
    var request = require('request');
    var options = {
    'method': 'GET',
    'url': 'http://apis.data.go.kr/6260000/BusanLibraryInfoService/getLibraryInfo?serviceKey=4NcrAr4OjUAlIMI6hEZ0aodkuOqAm8YWJUmnHU94JZPIKGG8CTFAmfY212NLrwk%2B%2BzAGvQHLfxR9nlvi0rcBjA%3D%3D&numOfRows=10000&resultType=json&' + encodeURI(word),
    'headers': {
        'Cookie': 'JSESSIONID=Oou1zEasxLBBYOXkPt8GTV8Q0c0QmPta0Ic5aSVxcq916au17prdyC5C0U1Mvvm8.amV1c19kb21haW4vbmV3c2t5Mw=='
    }
    };
    request(options, function (error, response) {
        if (error) throw new Error(error);
            console.log(response.body);
            res.send(response.body);
    });
})

app.get('/search_book', function(req, res) {
    window_ethereum = req.query.word;
    console.log(window_ethereum)
    getAccounts();
    //console.log(word);
    // var request = require('request');
    // var options = {
    // 'method': 'GET',
    // 'url': 'http://apis.data.go.kr/6260000/BookNewListService/getBookNewList?serviceKey=4NcrAr4OjUAlIMI6hEZ0aodkuOqAm8YWJUmnHU94JZPIKGG8CTFAmfY212NLrwk%2B%2BzAGvQHLfxR9nlvi0rcBjA%3D%3D&numOfRows=10000&resultType=json&' + encodeURI(word),
    // 'headers': {
    //     'Cookie': 'JSESSIONID=Oou1zEasxLBBYOXkPt8GTV8Q0c0QmPta0Ic5aSVxcq916au17prdyC5C0U1Mvvm8.amV1c19kb21haW4vbmV3c2t5Mw=='
    // }
    // };
    // request(options, function (error, response) {
    //     if (error) throw new Error(error);
    //         console.log(response.body);
    //         res.send(response.body);
    // });
})

//응답 대기 모드로 켜는 것
app.listen(port, () => console.log(`Example app listening at http://localhost:${port}`))

