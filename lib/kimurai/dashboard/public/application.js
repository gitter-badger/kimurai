$(document).ready(function() {
  let rootResourse = location.pathname.replace(/(^\/.*?)\/(.*)/, '$1')
  $(`a[href="${rootResourse}"]`).closest('li').addClass('active');
});
