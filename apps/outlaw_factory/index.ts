import {S3} from 'aws-sdk';
import fs from 'fs';
import { Command } from "commander";
import path from "path";
import Path from "path";
import {
    deserializeBcs,
    JSTypes,
    moveStructValidator,
    serializeByField,
    parseViewResults,
    bcs
  } from "@capsulecraft/serializer;

// region: 'eu-central-1',
// accessKeyId: 'AKIAXEZRZEA52A7AJRTJ',
// secretAccessKey: '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'


const program = new Command();


program
  .option(
      "-f, --folderPath <folderPath>",
      "Folder path containing images and json metadata files"
  )
  .option(
      "-r. --regionS3 <region>",
      "S3 region"
  )
  .option(
      "-b, --bucket <bucket>",
      "The s3 bucket to upload the images"
  )
  .option(
      "-a, -accessKey <accessKey>",
      "Access key id, of the s3 user"
  )
  .option(
      "-s, --secretAccessKey <secretAccessKey>",
      "Secret access key of the s3 user"
  )
  .option(
      "-c, --configFile <configFile>",
      "The path for the configuration file, containing nececairy data for uploading Outlaws"
  )
  .action((options) => {
      if (options) {
          console.log(`Uploading images from ${options.folderPath} to ${options.regionS3} - ${options.bucket}`)
      }
      else {
          return false
      }


    const s3 = new S3({
        region: options.region,
        accessKeyId: options.accessKey,
        secretAccessKey: options.secretAccessKey
    });

    const fileMap = scanAndUpload(options.folderPath, options.bucket, s3);

    for (const [fileID, url] of Object.entries(fileMap)) {
        const metadata = loadMetadata(options.folderPath, fileID)
        metadata["image"] = url

    }
    

  }

  )

const scanAndUpload = async (path: string, bucket: string, s3: S3): Promise<Record<string, string>> => {
    const fileMap: Record<string, string> = {}
    try {
        const files = await fs.promises.readdir(path);
        for (const file of files) {
            if (file.includes('.jpg') || file.includes('.png') || file.includes('.jpeg')) {
                const filePath = path + '/' + file;
                const fileContent = await fs.promises.readFile(filePath);
                const s3Params = {
                    Bucket: bucket,
                    Key: file,
                    Body: fileContent,
                };
                const s3UploadData = await s3.upload(s3Params).promise();
                const expiration = 60 * 60 * 24 * 7 // 1 week
                const url = s3.getSignedUrl("getObject", {Bucket: bucket, Key: s3UploadData.Location.split(".com/")[1], Expires: expiration})
                console.log(`File uploaded successfully. ${s3UploadData.Location}, ${url}`);
                const fileID = Path.parse(file).name;
                fileMap[fileID] = url;
            }
        }
    } catch (error) {
        console.log(error);
    }
    return fileMap;
}

function loadMetadata(folderPath: string, fileID: string){
    const fileContent = fs.readFileSync(path.join(folderPath, fileID, ".json"), "utf-8")
    const metadata = JSON.parse(fileContent);
    return metadata
}


class OutlawFactory{
    private schema = {
        name: 'string',
        description: 'Option<string>',
        image: 'string',
        power_level: 'u64'
      } as const;
    private packageID: string;
    private schemaID: string;

    constructor(packageID: string, schemaID: string){
        this.packageID = packageID;
        this.schemaID = schemaID;
        this.validator = 
    }

    
}