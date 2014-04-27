$(document).ready(function() {
  $.get('http://localhost:3000/stations', function(data) {
    var stations = data;
    $.each(stations, function(index, station) {
      $('#stations').append($('<option>').text(station.name).attr('value', station.wmo));
    });
  });
});