var Auction_sol;
var Item_sol;
var Supply_sol;
let governance;
var flag = false;
let exrate = 1.0;


// 페이지 로드될때마다, 컨트랙트랑 연동시켜주기

const options = {
	filter: {
	},
	fromBlock: 'latest'
}


async function test(){
	var _itemId = 1000000;
	
	console.log(idx);
	console.log(idx.length);
}



async function startApp() {
	var ItemAddress = "0xeFf3204ef49f3601f81A9fE26BC4cFB8b0c060Fc";
	var SupplyAddress = "0x271693659B7d3D9aFcee38A263FC7B61b23BE7Fb";
	var AuctionAddress = "0xf8a91e88a51D0B3A0e74aa67291E4D949D711ce2";
	governance = AuctionAddress;
		
	Auction_sol = await new web3.eth.Contract(AuctionABI, AuctionAddress);
	console.log("Auction Create");
	Item_sol = await new web3.eth.Contract(ItemABI, ItemAddress);
	Supply_sol = await new web3.eth.Contract(SupplyABI, SupplyAddress);
	console.log("Supply create");
	Auction_sol.events.TransferSingle(options, async (error, event) => {
		if (error) {
		console.log(error)
		return
		}
		console.log("거래 트랜잭션 발생");
	
	
		console.log(event);
	
		// Initiate transaction confirmation	
		return
	  });
}



window.addEventListener('load', function() {
	// Web3가 브라우저에 주입되었는지 확인(Mist/MetaMask)
	if (typeof web3 !== 'undefined') {
	// Mist/MetaMask의 프로바이더 사용
		web3 = new Web3(window.ethereum);

		
 		//console.log(web3)
	} else {
		this.alert("메타 마스크를 설치하세요");
	}

	startApp();


	console.log("smart contract , 메타마스크 연결 완료");
	
})
