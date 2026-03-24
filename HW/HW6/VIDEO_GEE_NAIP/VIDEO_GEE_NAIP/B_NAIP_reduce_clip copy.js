// You need to create a geometry, otherwise this will not work. 
var geometry = ee.Geometry.Polygon(
  [[[-118.508578170166, 37.412491978341436],
    [-118.508578170166, 37.32517871742773],
    [-118.34035002075194, 37.32517871742773],
    [-118.34035002075194, 37.412491978341436]]], null, false);

var dataset = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.date('2017-01-01', '2018-12-31'));

var trueColor = dataset.select(['R', 'G', 'B']);

var trueColorVis = {
  min: 0,
  max: 255,
};

var california = trueColor.median().clip(geometry)
Map.setCenter(-118.39511, 37.36354, 15); 
Map.addLayer(california, trueColorVis, 'True Color');