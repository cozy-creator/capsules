import {serializeBcs, bcs } from "@capsulecraft/serializer";

const input = <HTMLInputElement>document.getElementById("input");
const output = <HTMLOutputElement>document.getElementById("output");
const serializeBtn = document.getElementById("serialize-btn");

serializeBtn.addEventListener("click", function () {
  console.log("asdfafsdf");
  const inputValue = input.value;
  const outputValue = serializeText(inputValue);
  output.value = JSON.stringify(outputValue);
});

function serializeText(text: string): number[][]{
  const serializedData: number[][] = [];
  let text_trimmed =  text.trim();
    if (text_trimmed.slice(0, 1) !== "[" &&  text_trimmed.slice(-1) !== "]"){
      throw new Error("The first and the last characters must be brackets.");
    }
    const encodedData = text.slice(1, text.length -1);
    const regex = /,(?![^\[]*\])/g;
    const items = encodedData.split(regex);
    const pairs = items.map(item => item.split(":"));
    pairs.forEach(([data, type])=>{
      type = type.trim()
      const parsedData = JSON.parse(data);
      console.log(parsedData, type);
      const bytesArray = serializeBcs(bcs, type, parsedData)
      serializedData.push(bytesArray);
    })
    console.log(serializedData);
 
    return serializedData
}

