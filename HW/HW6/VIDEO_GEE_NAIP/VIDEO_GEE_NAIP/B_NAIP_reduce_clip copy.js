// You need to create a geometry, otherwise this will not work. 

var dataset = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.date('2017-01-01', '2018-12-31'));
var trueColor = dataset.select(['R', 'G', 'B']);
var trueColorVis = {
  min: 0,
  max: 255,
};
var unc = trueColor.median().clip(geometry)
Map.setCenter(-79.04879, 35.90418, 15); 
Map.addLayer(unc, trueColorVis, 'True Color');