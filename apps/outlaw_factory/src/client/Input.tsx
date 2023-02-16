import React, { useState } from 'react';
import process from 'process';
import { useNavigate } from 'react-router-dom';


function TextInputWithButton() {
  const navigate = useNavigate();
  const [text, setText] = useState('');

  const handleSubmit = async () => {
      const serverIp = process.env.SERVER_IP || 'localhost'; // get server IP from environment variable or use 'localhost' as fallback
      const response = await fetch(`http://${serverIp}:3002/generate`, { // add prefix to the URL
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: ""
      });
      const data = await response.json();
      console.log("afasdf", data); // do something with the response data
      navigate(`/hash/${data.hash}`); // redirect to the generated hash page

    // }
  };

  const handleInputChange = (event: any) => {
    setText(event.target.value);
  };

  return (
    <div className='container' style={{marginTop: '30px'}}>
      {/* <input className='textarea' type="text" value={text} onChange={handleInputChange} /> */}
      <button className='button' onClick={handleSubmit}>Generate</button>
    </div>
  );
}

export default TextInputWithButton;
