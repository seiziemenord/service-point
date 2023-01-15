<script>
  var breeds = <%= breeds.to_json %>;
  var input = document.getElementById("breed");
  new Awesomplete(input, {
    list: breeds
  });
</script>