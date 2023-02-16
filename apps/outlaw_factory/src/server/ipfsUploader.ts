import { NFTStorage, File } from 'nft.storage'
import mime from 'mime'
import fs from 'fs'
import path from 'path'
import  fetch  from 'node-fetch';


const NFT_STORAGE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweGQyRDU5RTdiZTkxMDI4Rjc0OGRGNmJhNjhkMDU2NTVBMDhFQTRGZDQiLCJpc3MiOiJuZnQtc3RvcmFnZSIsImlhdCI6MTY3NTk3MDkyMjgxNywibmFtZSI6ImNhcHN1bGUtYXJ0LWVuZ2luZSJ9.MoladaEZSdjFp715w6R2dO2Mbd0f-HfPbbRIYzB_rZA";
const IPFS_GATEWAY = "nftstorage" // or "ipfs.io"

/**
  * Reads an image file from `imagePath` and stores an NFT with the given name and description.
  * @param {string} filePath the path to an image file
  * @param {string} name a name for the NFT
  * @param {string} description a text description for the NFT
  */
async function storeNFT(filePath: string, name: string, description: string) {
    // load the file from disk
    const image = await fileFromPath(filePath)

    // create a new NFTStorage client using our API key
    const nftstorage = new NFTStorage({ token: NFT_STORAGE_KEY })

    // call client.store, passing in the image & metadata
    return nftstorage.store({
        image,
        name,
        description,
    })
}

/**
  * A helper to read a file from a location on disk and return a File object.
  * Note that this reads the entire file into memory and should not be used for
  * very large files. 
  * @param {string} filePath the path to a file to store
  * @returns {File} a File object containing the file content
  */
async function fileFromPath(filePath: string) {
    const content = await fs.promises.readFile(filePath)
    const type = mime.getType(filePath) || ""
    return new File([content], path.basename(filePath), { type })
}

async function extractIpfsDetails(ipfsString: string) {
    const regex = /^ipfs:\/\/([a-zA-Z0-9]+)(\/.*)/;
    const match = regex.exec(ipfsString);
  
  
    return {
        hash: match ?  match[1] : "",
        filePath: match? match[2]: "",
      };
  }

async function getIpfsUrl(hash: string, path: string) {
    let url = '';
    
    // @ts-ignore
    if (IPFS_GATEWAY === 'ipfs.io') {
      url = `https://ipfs.io/ipfs/${hash}${path}`;
    } else if (IPFS_GATEWAY === 'nftstorage') {
      url = `https://${hash}.ipfs.nftstorage.link${path}`;
    }
  
    return url;
  }
  

async function readIpfsJsonFile(ipfsUrl: string): Promise<Record<string, string>> {
  let response;
  let retries = 3;
  let json: Record<string, string> = {};

  // I am disabling retry, because is causing an infinite loop. I need to look into it. For
  // now its working as it is.
  
//   while (retries > 0) {
//     try {
      const ipfsDetails = await extractIpfsDetails(ipfsUrl);
      const url = await getIpfsUrl(ipfsDetails.hash, ipfsDetails.filePath)
      console.log(url);
      response = await fetch(url);
      json = await response.json() as Record<string, string>;
      
//     } catch (error) {
//       console.error(`Fetch failed: ${error}. Retrying in 2 seconds...`);
//       retries--;
//       await new Promise(resolve => setTimeout(resolve, 2000));
//     }
//   }

  if (!response) {
    throw new Error('Fetch failed after multiple attempts');
  }
  
  return json;
}
  async function getFileUrl(metadataUrl: string) {
    const metadata = await readIpfsJsonFile(metadataUrl);
    const imageIpfsUrl = metadata.image;
    const ipfsDetail = await extractIpfsDetails(imageIpfsUrl);
    return await getIpfsUrl(ipfsDetail.hash, ipfsDetail.filePath);
  }

async function uploadFile(filePath: string, name?:string, description?:string): Promise<string> {
  name = name || path.basename(filePath).split(".")[0];
  description = description || path.basename(filePath);
  let result;
  let retries = 3;
  while (retries > 0) {
    try {
      result = await storeNFT(filePath, name, description);
      break;
    } catch (error) {
      console.error(`Upload failed: ${error}. Retrying in 3 seconds...`);
      retries--;
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
  }

  if (!result) {
    throw new Error('Upload failed after multiple attempts');
  }

  console.log(result)
  const fileUrl = getFileUrl(result.url);
  return fileUrl
}
/**
 * The main entry point for the script that checks the command line arguments and
 * calls storeNFT.
 * 
 * To simplify the example, we don't do any fancy command line parsing. Just three
 * positional arguments for imagePath, name, and description
 */
async function main() {
    const args = process.argv.slice(2)
    if (args.length !== 1) {
        console.error(`usage: ${process.argv[0]} <folderPath>`)
        process.exit(1)
    }

    const [folderPath] = args
    try {
      const files = await fs.promises.readdir(folderPath);
      for (const file of files) {
        if (file.includes('.jpg') || file.includes('.png') || file.includes('.jpeg')) {
          const filePath = folderPath + '/' + file;
          console.log("Uploading file: ", file);
          const fileUrl = await uploadFile(filePath);
          console.log(fileUrl);
        }
      }
    } catch (errror){
      console.log(errror)
    }
}
    

// Don't forget to actually call the main function!
// We can't `await` things at the top level, so this adds
// a .catch() to grab any errors and print them to the console.
main()
  .catch(err => {
      console.error(err)
      process.exit(1)
  })