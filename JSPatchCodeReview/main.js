

require("UIAlertView");

defineClass("ViewController", {
btnClick: function(sender) {
var arrTest = ["arrTest"];
var strCrash = arrTest[0];

var alert = UIAlertView.alloc().initWithTitle_message_delegate_cancelButtonTitle_otherButtonTitles("JSPatchAmend", "Success", null, "Yes", null, null);
    alert.show();
}
}, {}, {});
