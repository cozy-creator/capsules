<template>
  <v-row>
    <v-col cols="12" md="8" class="mx-auto">
      <v-row>
        <v-col cols="12" md="6">
          <v-label class="mb-2">Start Date</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="date"
            variant="outlined"
          />
        </v-col>

        <v-col cols="12" md="6">
          <v-label class="mb-2">End Date</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="date"
            variant="outlined"
          />
        </v-col>
      </v-row>

      <v-row>
        <v-col cols="12" md="6">
          <v-label class="mb-2">Mint Price</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="number"
            variant="outlined"
          />
        </v-col>

        <v-col cols="12" md="6">
          <v-label class="mb-2">Total Items</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="number"
            variant="outlined"
          />
        </v-col>
      </v-row>

      <div class="my-2">
        <v-label class="mb-2">Items Schema</v-label>
        <v-textarea
          hide-details
          rows="2"
          readonly
          value='["String", "String"]'
          density="comfortable"
          variant="outlined"
        />
      </div>

      <div class="my-2">
        <v-label class="mb-2">Items Description</v-label>
        <v-textarea
          rows="2"
          hide-details
          density="comfortable"
          variant="outlined"
        />
      </div>

      <v-row>
        <v-col cols="12" md="6">
          <v-switch label="Random Mint" inset />
        </v-col>
      </v-row>

      <v-btn flat color="primary" block>Create</v-btn>
    </v-col>
  </v-row>
</template>
