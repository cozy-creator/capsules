import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";

function HashPage() {
    const { hash } = useParams();
  const [imageUrl, setImageUrl] = useState("");
  const [data, setData] = useState(null);

  useEffect(() => {
    const getImageUrl = async () => {
      const url = `http://images.crypto-algotrading.com/${hash}`;
      console.log(url)
      setImageUrl(url);
    };
    getImageUrl();

    const fetchData = async () => {
      console.log("Calling", hash);
      const response = await fetch(`/metadata/${hash}`);
      const data = await response.json();
      setData(data);
      console.log("data", data)
    };
    fetchData();
  }, [hash]);

  return (
      <div style={{ display: "flex", justifyContent: "space-between", marginTop:"32px" }}>
    <div style={{ display: "flex", flexDirection: "row", alignItems: "center" }}>
    <div style={{ marginRight: "32px" }}>
      <img
        src={imageUrl}
        alt="Generated Image"
        style={{ width: "500px", height: "300px" }}
      />
    </div>
    {data && (
      <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
        {Object.entries(data).map(([key, value]) => (
          <p key={key}>
            <span style={{ fontWeight: "bold" }}>{key}:</span> {value}
          </p>
        ))}
      </div>
    )}
  </div>
  </div>
    // <div>
    //   <div>
    //     <img
    //       src={imageUrl}
    //       alt="Generated Image"
    //       style={{ width: "500px", height: "300px" }}
    //     />
    //   </div>
    //   {data && (
    //     <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
    //       {Object.entries(data).map(([key, value]) => (
    //         <p key={key}>
    //           <span style={{ fontWeight: "bold" }}>{key}:</span> {value}
    //         </p>
    //       ))}
    //     </div>
    //   )}
    // </div>
  );
}

export default HashPage;
