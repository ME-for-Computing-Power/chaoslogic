var total = 134;

var callerdata = {
    'aaData': [["<a href='./node2Time.html' title='unnamed$$_0'>unnamed$$_0</a>", 62, 63, 2, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:291\")'>tb.sv:291</a>"],
        ["<a href='./node2Time.html' title='unnamed$$_0'>unnamed$$_0</a>", 1, 63, 2, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:294\")'>tb.sv:294</a>"]],
    'aoColumns': [
        {'sTitle': 'Caller Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
    'aoColumnDefs': [
        {'fnRender': function(oObj, sVal){
            var input = sVal * 1000000 * 0.94 / 134;
            var ret;
            if(input>1000000){
                ret = (input/1000000).toFixed(1).toString() + ' s';
            }else if(input>1000){
                ret = (input/1000).toFixed(1).toString() + ' ms';
            }else if(input==0){
                return '0';
            }else{
                ret = input.toFixed(1).toString() + ' us';
            }
            return ret + ' (' + (sVal/total*100).toFixed(1).toString()+'%)';
        }, 'aTargets': [ 1, 2, 3]
        }
    ],
    'bInfo': false,
    'bFilter': false,
    'sScrollX': '530px',
    'sScrollY': '140px',
    'bPaginate': false,
    'bScrollCollapse': true
}
var calleedata = {
    'aaData': [["<a href='./node2Time.html' title='unnamed$$_0'>unnamed$$_0</a>", 62, 63, 2, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:291\")'>tb.sv:291</a>"],
        ["<a href='./node3Time.html' title='test_rand_frame'>test_rand_frame</a>", 21, 22, 5, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:5\")'>tb.sv:5</a>"],
        ["<a href='./node4Time.html' title='check_output'>check_output</a>", 39, 39, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:292\")'>tb.sv:292</a>"],
        ["<a href='./node2Time.html' title='unnamed$$_0'>unnamed$$_0</a>", 1, 63, 2, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:294\")'>tb.sv:294</a>"],
        ["<a href='./node3Time.html' title='test_rand_frame'>test_rand_frame</a>", 1, 22, 5, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:294\")'>tb.sv:294</a>"]],
    'aoColumns': [
        {'sTitle': 'Callee Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
    'aoColumnDefs': [
        {'fnRender': function(oObj, sVal){
            var input = sVal * 1000000 * 0.94 / 134;
            var ret;
            if(input>1000000){
                ret = (input/1000000).toFixed(1).toString() + ' s';
            }else if(input>1000){
                ret = (input/1000).toFixed(1).toString() + ' ms';
            }else if(input==0){
                return '0';
            }else{
                ret = input.toFixed(1).toString() + ' us';
            }
            return ret + ' (' + (sVal/total*100).toFixed(1).toString()+'%)';
        }, 'aTargets': [ 1, 2, 3]
        }
    ],
    'bInfo': false,
    'bFilter': false,
    'sScrollX': '530px',
    'sScrollY': '140px',
    'bPaginate': false,
    'bScrollCollapse': true
}

$(document).ready(function() {
    $('#callertable').dataTable(callerdata);
    $('#calleetable').dataTable(calleedata);
    $('.dataTables_scrollHeadInner').width('100%');
    $('.dataTable').width('100%');
    prettyPrint();
});