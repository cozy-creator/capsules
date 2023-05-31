<template>
  <div class="mb-5">
    <h2>Dispenser 0x45Dc....Ef62Cf</h2>
    <!-- <p>
      https://axkdkd.com/rec

      <v-btn flat icon="mdi-content-copy" size="small" density="compact" />
    </p> -->
  </div>

  <v-row>
    <v-col cols="12" md="5">
      <div>
        <h4 class="mb-3">Dispenser Details</h4>

        <div class="d-flex">
          <span>Mint Price:</span>
          <v-spacer />
          <span>10 SUI</span>
        </div>
        <v-divider class="my-3" />
        <div class="d-flex">
          <span>Dispenser Balance:</span>
          <v-spacer />
          <span>10 SUI</span>
        </div>
        <v-divider class="my-3" />
        <div class="d-flex">
          <span>Total Items:</span>
          <v-spacer />
          <span>10</span>
        </div>
        <v-divider class="my-3" />
        <div class="d-flex">
          <span>Items Minted:</span>
          <v-spacer />
          <span>0</span>
        </div>
        <v-divider class="my-3" />
        <div class="d-flex">
          <span>Start Date:</span>
          <v-spacer />
          <span>{{ new Date().toDateString() }}</span>
        </div>
        <v-divider class="my-3" />
        <div class="d-flex">
          <span>End Date:</span>
          <v-spacer />
          <span>{{ new Date().toDateString() }}</span>
        </div>
      </div>

      <v-divider class="mb-5 mt-10" />

      <div>
        <div class="d-flex">
          <h4 class="mb-3">Withdraw Balance</h4>
          <v-spacer />
          <p>10 SUI</p>
        </div>

        <v-text-field
          color="primary"
          density="comfortable"
          variant="outlined"
          type="number"
        />
        <v-btn color="primary" variant="tonal" flat block>Withdraw</v-btn>
      </div>
    </v-col>

    <v-col cols="12" md="7">
      <div class="d-flex">
        <h4 class="mb-3">Load Dispenser</h4>
        <v-spacer />
        <router-link to="">
          <v-icon icon="mdi-download" />
          sample
        </router-link>
      </div>

      <v-sheet class="mb-3 pa-3" color="plaster">
        <p class="mb-3">File format:</p>

        <pre>
[{
    name: "Item #0001"
    url: "https://someurl.com/1.png",
},
{
    name: "Item #0002"
    url: "https://someurl.com/2.png",
}]
            </pre
        >
      </v-sheet>

      <v-file-input
        prepend-icon="mdi-upload"
        density="comfortable"
        label="Select File"
        variant="outlined"
        color="primary"
        show-size
      />

      <v-btn color="primary" variant="tonal" flat block>Load Dispenser</v-btn>
    </v-col>
  </v-row>
</template>
