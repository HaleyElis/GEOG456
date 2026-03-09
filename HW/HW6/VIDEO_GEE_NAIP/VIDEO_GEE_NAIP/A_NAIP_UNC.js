// Code starting from: 
// https://code.earthengine.google.com/?scriptPath=Examples%3ADatasets%2FUSDA%2FUSDA_NAIP_DOQQ

var dataset = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.date('2017-01-01', '2018-12-31'));
var trueColor = dataset.select(['R', 'G', 'B']);
var trueColorVis = {
  min: 0,
  max: 255,
};
Map.setCenter(-79.04879, 35.90418, 15); // I changed the long, lat to have the center in UNC
Map.addLayer(trueColor, trueColorVis, 'True Color');
