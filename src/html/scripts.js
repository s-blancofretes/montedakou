const audio = document.getElementById("player");
const playPauseButton = document.getElementById("play-pause-button");
const volumeControl = document.getElementById("volumeSlider");
const nowPlayingText = document.getElementById("now-playing-text")
var sourceUrl = audio.getAttribute("src");

let isPlaying = false;

function getNowPlaying(){
    $.ajax({
        url: 'nowplaying.php',
        type: 'GET',
        success: function (response){
            var title = JSON.parse(response).icestats.source.title;
            nowPlayingText.textContent = "Now playing: " + title;
        },
        error : function(){
            console.log('Error getting currently playing track');
        }    
        })
}

playPauseButton.addEventListener("click", () => {
    if (isPlaying) {
        audio.pause();
        audio.setAttribute("src", "");
        setTimeout(function () { 
            audio.load();
        });
        playPauseButton.className = "playing"
    } else {
        audio.setAttribute("src", sourceUrl);
        audio.load();
        audio.play();
        playPauseButton.className = "paused"
    }
    isPlaying = !isPlaying;
});

volumeControl.addEventListener("input", () => {
    audio.volume = volumeControl.value;
})
getNowPlaying();
var interval = setInterval(getNowPlaying, 10000);