(function(d){var h=[];d.loadImages=function(a,e){"string"==typeof a&&(a=[a]);for(var f=a.length,g=0,b=0;b<f;b++){var c=document.createElement("img");c.onload=function(){g++;g==f&&d.isFunction(e)&&e()};c.src=a[b];h.push(c)}}})(window.jQuery||window.Zepto);
 $.fn.hasAttr = function(name) { var attr = $(this).attr(name); return typeof attr !== typeof undefined && attr !== false; };

$(document).ready(function() {
r = function() {
$('.img').attr('src', (window.devicePixelRatio > 1) ? ((window.devicePixelRatio > 2) ? 'images/itunesartwork-512-600.png' : 'images/itunesartwork-512-400.png') : 'images/itunesartwork-512-200.png');
$('.img-2').attr('src', (window.devicePixelRatio > 1) ? ((window.devicePixelRatio > 2) ? 'images/pasted-image-666.png' : 'images/pasted-image-444.png') : 'images/pasted-image-222.png');
$('.img-3').attr('src', (window.devicePixelRatio > 1) ? ((window.devicePixelRatio > 2) ? 'images/img_7625-1125.jpg' : 'images/img_7625-750.jpg') : 'images/img_7625-375.jpg');
$('.img-4').attr('src', (window.devicePixelRatio > 1) ? ((window.devicePixelRatio > 2) ? 'images/img_7626-1125.jpg' : 'images/img_7626-750.jpg') : 'images/img_7626-375.jpg');
$('.img-5').attr('src', (window.devicePixelRatio > 1) ? ((window.devicePixelRatio > 2) ? 'images/img_7627-1125.jpg' : 'images/img_7627-750.jpg') : 'images/img_7627-375.jpg');
$('.img-6').attr('src', (window.devicePixelRatio > 1) ? ((window.devicePixelRatio > 2) ? 'images/img_7628-1125.jpg' : 'images/img_7628-750.jpg') : 'images/img_7628-375.jpg');
$('.img-8').attr('src', (window.devicePixelRatio > 1) ? ((window.devicePixelRatio > 2) ? 'images/madewithsparkle-570.png' : 'images/madewithsparkle-380.png') : 'images/madewithsparkle-190.png');};
$(window).resize(r);
r();

});