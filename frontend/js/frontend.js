
var chart;
var chartData = [];
var chartCursor;

$(document).ready(function() {
  $.get('http://localhost:3000/stations', function(data) {
    $('#station-select').append($('<option>').text('').attr('value', ''));

    var stations = data;
    $.each(stations, function(index, station) {
      $('#station-select').append($('<option>').text(station.name).attr('value', station.wmo));
    });
  });

  $('#station-select').change(function(e) {
    var station_wmo = e.target.value;
    loadChart(station_wmo);
  });
});

function loadChart(station_wmo) {
  // AmCharts.ready(function () {
    // load chart 
    $.get('http://localhost:3000/stations/'+station_wmo, function(data) {
      for (var i=0; i < data.length; i++) {
        var row = data[i];

        chartData.push({
          date: new Date(row.year, row.month-1, row.day),
          temp: row.temp
        });
      }

      chart = new AmCharts.AmSerialChart();
      chart.pathToImages = "js/amcharts/images/";
      chart.dataProvider = chartData;
      chart.categoryField = "date";
      chart.balloon.bulletSize = 5;

      chart.addListener("dataUpdated", zoomChart);

      // axes
      
      // category
      var categoryAxis = chart.categoryAxis;
      categoryAxis.parseDates = true; // as our data is date-based, we set parseDates to true
      categoryAxis.minPeriod = "DD"; // our data is daily, so we set minPeriod to DD
      categoryAxis.dashLength = 1;
      categoryAxis.minorGridEnabled = true;
      categoryAxis.twoLineMode = true;
      categoryAxis.dateFormats = [{
          period: 'fff',
          format: 'JJ:NN:SS'
      }, {
          period: 'ss',
          format: 'JJ:NN:SS'
      }, {
          period: 'mm',
          format: 'JJ:NN'
      }, {
          period: 'hh',
          format: 'JJ:NN'
      }, {
          period: 'DD',
          format: 'DD'
      }, {
          period: 'WW',
          format: 'DD'
      }, {
          period: 'MM',
          format: 'MMM'
      }, {
          period: 'YYYY',
          format: 'YYYY'
      }];

      categoryAxis.axisColor = "#DADADA";

      // value
      var valueAxis = new AmCharts.ValueAxis();
      valueAxis.axisAlpha = 0;
      valueAxis.dashLength = 1;
      chart.addValueAxis(valueAxis);

      // graph
      var graph = new AmCharts.AmGraph();
      graph.title = "red line";
      graph.valueField = "temp";
      graph.bullet = "round";
      graph.bulletBorderColor = "#FFFFFF";
      graph.bulletBorderThickness = 2;
      graph.bulletBorderAlpha = 1;
      graph.connect = false;
      graph.lineThickness = 2;
      graph.lineColor = "#5fb503";
      graph.negativeLineColor = "#efcc26";
      graph.hideBulletsCount = 50; // this makes the chart to hide bullets when there are more than 50 series in selection
      chart.addGraph(graph);

      // cursor
      chartCursor = new AmCharts.ChartCursor();
      chartCursor.cursorPosition = "mouse";
      chartCursor.pan = false;
      chartCursor.zoomable = true;
      chart.addChartCursor(chartCursor);

      // scrollbar
      var chartScrollbar = new AmCharts.ChartScrollbar();
      chart.addChartScrollbar(chartScrollbar);

      chart.creditsPosition = "bottom-right";

      chart.write("chartdiv");
    });
  // });
}

function zoomChart() {
  // different zoom methods can be used - zoomToIndexes, zoomToDates, zoomToCategoryValues
  chart.zoomToIndexes(chartData.length - 40, chartData.length - 1);
}

// changes cursor mode from pan to select
function setPanSelect() {
  if (document.getElementById("rb1").checked) {
    chartCursor.pan = false;
    chartCursor.zoomable = true;
  } else {
    chartCursor.pan = true;
  }
  chart.validateNow();
}
