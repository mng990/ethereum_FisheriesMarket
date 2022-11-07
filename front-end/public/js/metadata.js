const root = "/testmilk";
const dir = "/testmilk/testItem";
const dirAuc = "/testmilk/testAuc";
const dirName = "testItem";
const dirAucName = "testAuc";

async function buildItemData(_itemId, _fish, _kg, _count, _from, _CIDArr){
                var metadata = new Object();
                var descript = "This is metadata of " + _fish;
                var userAccounts = await web3.eth.getAccounts();

                
                metadata.name = _fish.toString();
                metadata.weight = _kg.toString();
                metadata.amount = _count.toString();
                metadata.origin = _from.toString();
                metadata.image = _CIDArr[0];  
                metadata.id = _itemId.toString();
                metadata.producer = userAccounts[0].toString();
                metadata.description = descript;              

                console.log(metadata);
                
                return JSON.stringify(metadata);
        }

async function writeAuctionData(auctionId, metadata, ipfs, update){
                var buf = new TextEncoder().encode(metadata);

                var pathIdx = auctionId.toString(16);
                pathIdx = pathIdx.padStart(64,'0');

                //console.log(metadata);
                
                //var ls = await ipfs.files.ls(dir);

                if(update){
                    await ipfs.files.rm(dirAuc+'/' + pathIdx+ '.json');
                }

                await ipfs.files.write(dirAuc+'/' + pathIdx+ '.json', buf, { create: true });


                //var jsonData = readMetadata(itemId, dir, ipfs);

                var dirCID = await ipfs.files.stat(root);
                dirCID = dirCID.cid.toString();
                console.log(dirCID);
        }

async function writeItemData(itemId, metadata, ipfs){
            var buf = new TextEncoder().encode(metadata);

            var pathIdx = itemId.toString(16);
            pathIdx = pathIdx.padStart(64,'0');

            //console.log(metadata);
            
            //var ls = await ipfs.files.ls(dir);

            //await ipfs.files.rm(dir+'/' + pathIdx+ '.json');

            await ipfs.files.write(dir+'/' + pathIdx+ '.json', buf, { create: true });


            //var jsonData = readMetadata(itemId, dir, ipfs);

            var dirCID = await ipfs.files.stat(root);
            dirCID = dirCID.cid.toString();
            console.log(dirCID);
    }

async function buildAuctionData(_auctionId, _itemId, _auctionTitle, _startPrice, _winningPrice, 
            _stock, _from, _to, _shippingFrom, _shippingTo, _startTime, _blockDeadLine){
                var auction = new Object();
                var descript = "This is auction data of "+_auctionTitle;
                auction.auctionId = parseInt(_auctionId);
                auction.itemId = parseInt(_itemId);
                auction.auctionTitle = _auctionTitle.toString();
                auction.startPrice = parseInt(_startPrice);
                auction.winningPrice = parseInt(_winningPrice);
                auction.stock = parseInt(_stock);
                auction.shippingFrom = _shippingFrom.toString();
                auction.shippingTo = _shippingTo.toString();
                auction.startTime = parseInt(_startTime);
                auction.blockDeadLine = parseInt(_blockDeadLine);
                auction.seller = _from.toString();
                auction.buyer = _to.toString();
                auction.description = descript;
    
                return JSON.stringify(auction);
            }
            async function buildNewAuctionData(_prevAuction, _bidderInfo){
                    var auction = new Object();
                    var bidderInfo = new Object();

                    console.log(auction);
                    console.log(bidderInfo);
                
                    auction = _prevAuction;
                    bidderInfo = _bidderInfo;
                    auction.buyer = _bidderInfo.from;
                    auction.shippingTo = _bidderInfo.shippingTo;
                    auction.winningPrice = _bidderInfo.amount;
                    auction.startTime = auction.startTime;
                    auction.blockDeadLine = auction.blockDeadLine;

        
                    return JSON.stringify(auction);
                }

async function getDirCID(_dir){

            var binary = await ipfs.files.stat(_dir)
            var result = binary.cid.toString();
            console.log(result);

            return result;
        }

async function mkdir(_dir, ipfs){
            await ipfs.files.mkdir(_dir);
            console.log((await ipfs.files.stat(_dir)).cid.toString());
        }

 async function buildGoldData(_CIDArr, ipfs){
            //await ipfs.files.mkdir(dir);

            var metadata = new Object();
            var descript = "This is metadata of " + "Meat&Milk Token";

                metadata.name = "MMT";
                metadata.amount = 10**18;
                metadata.image = _CIDArr[0];  
                metadata.id = 0;
                metadata.producer = governance;
                metadata.description = descript;
                
                
                var jdata = JSON.stringify(metadata);

                console.log(jdata);

                var buf = new TextEncoder().encode(jdata);

                console.log(jdata);

                var idx = (0).toString(16);
                idx = idx.padStart(64,'0');

                await ipfs.files.write(dir+'/'+idx+'.json', buf, { create: true });


                var readData = await readMetadata(0, dir,ipfs);

                dirCID = await ipfs.files.stat(dir);
                dirCID = dirCID.cid.toString();
                console.log(dirCID);
                
                return dirCID;

        }

        async function readMetadata(_id, _dir, ipfs){
            var pathIdx = _id.toString(16);
            pathIdx = pathIdx.padStart(64,'0');
            var path = _dir+"/"+pathIdx+".json";
            console.log(path);
            var len = 0;
            var chunks = [];
            for await(var chunk of ipfs.files.read(path)){
                chunks.push(chunk);
                len += chunk.length;
            }
            var cat = new Uint8Array(len);
            var idx = 0;
            for (chunk of chunks){
                cat.set(chunk, idx);
                idx += chunk.length;
            }
            console.log(cat)
            var jsonData = JSON.parse(new TextDecoder().decode(cat).toString());

            console.log(jsonData);

            return jsonData;
        }

        async function initDir(_CIDArr, ipfs){
            await ipfs.files.rm(root, {recursive: true});
            await mkdir(root, ipfs, {parent:true});
            await mkdir(dir, ipfs, {parent: true});
            await mkdir(dirAuc, ipfs, {parent:true});
            await buildGoldData(_CIDArr, ipfs);

            await getDirCID(root, ipfs);
        }

        async function getDirCID(_dir, ipfs){
            var dirCID = await ipfs.files.stat(_dir);
            dirCID = dirCID.cid.toString();
            console.log(dirCID);
        }

     