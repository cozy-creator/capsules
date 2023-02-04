const input = document.getElementById("input");
const output = document.getElementById("output");
const serializeBtn = document.getElementById("serialize-btn");
serializeBtn.addEventListener("click", function () {
    console.log("asdfafsdf");
    const inputValue = input.value;
    const outputValue = serializeText(inputValue);
    output.value = outputValue;
});
function serializeText(text) {
    const heterogenousArray = JSON.parse(text);
    console.log(heterogenousArray);
    const textOut = "wpa";
    return textOut;
}
export {};
