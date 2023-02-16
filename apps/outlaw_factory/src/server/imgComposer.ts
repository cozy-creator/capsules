import Jimp from 'jimp';
import fs, { readFile } from 'fs';
import uploadFile from './s3uploder';
const attributeHierarchy = ['Background', 'Head', 'Hair', 'Clothes']; 
const imagesFolder = '/home/george/projects/capsules/apps/outlaw_factory/static/images/'; 
const attributes = { 
  Background: "swirl.png",
  Clothes: 'floral.png',
  Head: 'faceA.png',
  Hair: 'bluehair.png'
};

async function readAttribute(attribute: string , attributeValue: string): Promise<Jimp> {
  console.log(attribute)
  // if (typeof attribute === 'string') {
    const imagePath = `${imagesFolder}${attribute}/${attributeValue}`;
    console.log("imagepath", imagePath)
    console.log(typeof imagePath)
    if (fs.existsSync(imagePath)) {
      console.log('The file exists at', imagePath);
    } else {
      console.log('The file does not exist at', imagePath);
    }
    return await Jimp.read(String(imagePath));
  // } else if (typeof attribute === 'object') {
  //   const subAttributes = Object.values(attribute);
  //   const subImages = await Promise.all(subAttributes.map((subAttribute) => readAttribute(subAttribute)));
  //   return subImages.reduce((prev, current) => prev.composite(current, 0, 0), new Jimp(1000, 1000));
  // } else {
  //   throw new Error(`Invalid attribute type: ${typeof attribute}`);
  // }
}

async function composeImage(attributes: { [key: string]: any },imageName?:string, hierarchy?: string[]) {
  const hierarchyZ = hierarchy || attributeHierarchy
  const name = imageName || "spidy.png"
  const sortedAttributes = Object.fromEntries(
    Object.entries(attributes).sort(([key1], [key2]) => hierarchyZ.indexOf(key1) - hierarchyZ.indexOf(key2))
    );
  const images = await Promise.all(
    hierarchyZ.map(async (attribute) => {
      const attributeValue = attributes[attribute];
      return await readAttribute(attribute, attributeValue);
    })
  );
  const finalImage = images.reduce((prev, current) => prev.composite(current, 0, 0), new Jimp(1000, 1000));
  // console.log("FinalImage", finalImage)
  const buffer = await finalImage.getBufferAsync(Jimp.MIME_PNG);
  return uploadFile(buffer, name)
  // finalImage.write('composed.png');
  // console.log("Image composed")
  // return 'composed.png'
}

// composeImage(attributes, attributeHierarchy);

export  { composeImage }