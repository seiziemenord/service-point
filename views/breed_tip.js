$(document).ready(function() {
  $("#breed").change(function() {
    var selectedBreed = $(this).val();
    $.get("/api/breed_tip", { breed: selectedBreed }, function(data) {
      $("#breed_tip").html(data.tip);
    });
  });
});

console.log(data)
