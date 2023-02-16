import * as express from 'express';
import { composeImage } from './imgComposer';
import path from "path";
const router = express.Router();

const attributes = { // given object with keys the attribute name and value the image for each attribute
    Background: "stars.png",
    Clothes: 'floral.png',
    Head: 'faceA.png',
    Hair: 'bluehair.png'
  };


router.get('/api/hello', (req, res, next) => {
    res.json('World');
});

router.get('/', (req, res, next) => {
    res.json('Express + TypeScript Server');
});


router.post('/generate', async (req, res) => {
    try {
        const result = await composeImage(attributes, "spidy2.png");
        console.log(result)
        res.status(200).json({ hash: result });
    }
    catch (err) {
        if (err instanceof Error) {
            // 👉️ err is type Error here
            res.status(500).json({ error: err.message });
          }
        
    }
});

// Define the GET endpoint with a parameter called "id"
router.get('/metadata/:id', (req, res) => {
    const id = parseInt(req.params.id); // Get the id from the URL parameter
    // const result = data.find(item => item.id === id); // Find the data with the matching id
    console.log("id")
    const result = attributes;
    if (result) {
      res.json(result); // Return the data as a JSON response
    } else {
      res.status(404).send('Not found'); // Return a 404 error if no data is found
    }
  });
  
  router.get('/*', function(req, res) {
    res.sendFile(path.join(__dirname, '../public/index.html'), function(err) {
      if (err) {
        res.status(500).send(err)
      }
    })
  })

export default router;