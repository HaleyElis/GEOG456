// You need to create a geometry, otherwise this will not work. 

var yearBefore = '2012'
var yearAfter = '2020'

// var dataset = ee.ImageCollection('USDA/NAIP/DOQQ')
//                   .filter(ee.Filter.date('2017-01-01', '2018-12-31'));

var datasetBefore = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.bounds(geometry))
                  .filter(ee.Filter.date(yearBefore +'-01-01', yearBefore+'-12-31'))

var datasetAfter = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.bounds(geometry))
                  .filter(ee.Filter.date(yearAfter +'-01-01', yearAfter+'-12-31'))


// var trueColor = dataset.select(['R', 'G', 'B']);
var befImg = datasetBefore.select(['R', 'G', 'B'])
befImg = befImg.median().clip(geometry);

var aftImg = datasetAfter.select(['R', 'G', 'B'])
aftImg = aftImg.median().clip(geometry);

var trueColorVis = {
  min: 0,
  max: 255,
};

Map.setCenter(-79.04879, 35.90418, 15); 
Map.addLayer(aftImg, trueColorVis, yearAfter);
Map.addLayer(befImg, trueColorVis, yearBefore);