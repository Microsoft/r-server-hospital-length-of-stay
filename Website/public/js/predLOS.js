// JavaScript Document

const Patients = { 
    "402690" : {
        image : "img/Anthony.png", 
        labimage : "img/lab1.PNG"
    },
    "402660" : {
        image : "img/Ana.png", 
        labimage : "img/lab2.PNG"
    },
    "402691" : {
        image : "img/Ashley.png", 
        labimage : "img/lab1.PNG"
    },
    "439181" : {
        image : "img/Bob.png", 
        labimage : "img/lab2.PNG"
    },
    "402695" : {
        image : "img/Emille.png", 
        labimage : "img/lab1.PNG"
    }
}

$(document).ready(function () {

    id = getUrlParameter("id");
    // in this example, we have two hard-coded users, Anthony and Ana
    // populate the patient page with either Anthony or Ana based on the id
        
    const Patient = Patients[id];

    if (Patient) {
        $("#nameImg").attr("src",Patient.image)
        $("#labImg").attr("src",Patient.labimage)
    } 
    $("#nameImg").click(function(){
        toggleImg();
        console.log("clicked")
    })

});

function getUrlParameter (sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
};

function toggleImg(){
    // toggle begtween the Exp and non-Exp versions of the  image
    // get the current src
    var imgNow = $('#nameImg').attr('src');
    imgNow = imgNow.substring(imgNow.indexOf("/")+1);
    var newImg;
    console.log(imgNow);
    if (imgNow.substring(0,3) == "Exp") {
        newImg = imgNow.substring(3);
    } else {
        newImg = "Exp" + imgNow;
    }
    console.log(newImg)
    $("#nameImg").attr("src","img/" + newImg)
}

function isEven(n) {
    return n == parseFloat(n)? !(n%2) : void 0;
  }

// enable clicking on the dashboard table rows to navigate to patient view
$('.table > tbody > tr').click(function() {
    window.document.location = $(this).data("href");
});

$('.table').on('click', '.clickable-row', function(event) {
    $(this).addClass('active').siblings().removeClass('active');
  });

// Predict patient LOS and add returned value to display
$("#admit_patient").click(function () {
    predLOS(id);    
    $("#admit_patient").addClass("disabled");
});

function predLOS (id) {
    // call /predict to get res.pred, the predicted LOS
    $.ajax({
        url: '/predict',
        type: 'GET',
        data: { eid: id },
        contentType: "application/json; charset=utf-8",
        error: function (xhr, error) {
            console.log(xhr); console.log(error);
        },
        success: function (res) {
            console.log("PatientID: " + id)
            console.log("Predicted LOS: " + res.pred)
            // now display the result
            los = Math.round(res.pred);
            showResult(los);

        }

    });  
}

   
var showResult = function (los){
    var today = new Date();
    var d = new Date();
    d.setDate(today.getDate() + los);  
    var dischargeDate = d.getMonth() + 1 + '/' + d.getDate() + '/' + d.getFullYear();
    if (los == 1) {
        dy = " day"
    } else { 
        dy= " days"
    }
 
    var dayofweek = new Array(7);
    dayofweek[0] = " *WEEKEND* Sunday ";
    dayofweek[1] = " Monday";
    dayofweek[2] = " Tuesday";
    dayofweek[3] = " Wednesday";
    dayofweek[4] = " Thursday";
    dayofweek[5] = " Friday";
    dayofweek[6] = " *WEEKEND* Saturday ";
    
    var dw = dayofweek[d.getDay()];    
    $("#losDays").html("Claim Submitted.  <br/>Estimated days to close: " + los + dy);
    $("#losDate").html(dischargeDate + dw )
}


        







