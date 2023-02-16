import * as AWS from 'aws-sdk';
import * as fs from 'fs';
import { Command } from "commander";

const program = new Command();

const s3 = new AWS.S3({
    region: 'eu-central-1',
    accessKeyId: 'AKIAXEZRZEA52A7AJRTJ',
    secretAccessKey: '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'
  });

// const Bucket = "files.capsulecraft.dev";
const Bucket = "images.crypto-algotrading.com";

export default async function uploadFile(buffer: Buffer, name: string) {
    try {
        // const fileContent = await fs.promises.readFile(filepath);
        const s3Params = {
            Bucket: Bucket,
            Key: name,
            Body: buffer,
            ACL: "public-read"
        };
        const s3UploadData = await s3.upload(s3Params).promise();
        console.log(`File uploaded successfully. ${s3UploadData.Location}`);
        return name
    }
    catch (error) {
        console.log(error);
    }
};

const scanAndUpload = async (path: string) => {
    try {
        const files = await fs.promises.readdir(path);
        for (const file of files) {
            if (file.includes('.jpg') || file.includes('.png') || file.includes('.jpeg')) {
                const filePath = path + '/' + file;
                const fileContent = await fs.promises.readFile(filePath);
                const s3Params = {
                    Bucket: Bucket,
                    Key: file,
                    Body: fileContent,
                };
                const s3UploadData = await s3.upload(s3Params).promise();
                const expiration = 60 * 60 * 24 * 7 // 1 week
                const url = s3.getSignedUrl("getObject", {Bucket: Bucket, Key: s3UploadData.Location.split(".com/")[1], Expires: expiration})
                console.log(`File uploaded successfully. ${s3UploadData.Location}, ${url}`);

            }
        }
    } catch (error) {
        console.log(error);
    }
}

// scanAndUpload("/home/george/projects/art-engine/build/images");



