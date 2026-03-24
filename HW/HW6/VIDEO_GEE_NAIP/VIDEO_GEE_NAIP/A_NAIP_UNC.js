// Code starting from: 
// https://code.earthengine.google.com/?scriptPath=Examples%3ADatasets%2FUSDA%2FUSDA_NAIP_DOQQ
// https://code.earthengine.google.com/85962bf309598f34d5de1bf6e22b6436
var dataset = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.date('2017-01-01', '2018-12-31'));
var trueColor = dataset.select(['R', 'G', 'B']);
var trueColorVis = {
  min: 0,
  max: 255,
};
Map.setCenter(-118.39511, 37.36354, 15); // I changed the long, lat to have the center in CA
Map.addLayer(trueColor, trueColorVis, 'True Color');
