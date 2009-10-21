/*
  #--
  #   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
  #
  #   This program is free software: you can redistribute it and/or modify
  #   it under the terms of the GNU Affero General Public License as published by
  #   the Free Software Foundation, either version 3 of the License, or
  #   (at your option) any later version.
  #
  #   This program is distributed in the hope that it will be useful,
  #   but WITHOUT ANY WARRANTY; without even the implied warranty of
  #   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  #   GNU Affero General Public License for more details.
  #
  #   You should have received a copy of the GNU Affero General Public License
  #   along with this program.  If not, see <http://www.gnu.org/licenses/>.
  #-- 
*/
MergeRequestControllerTest = TestCase("Merge request controller", {
    tearDown: function() {
        Gitorious.MergeRequestController.getInstance()._setTransport(jQuery);
    },
    testSingleton: function() {
        var firstController = Gitorious.MergeRequestController.getInstance();
        var secondController = Gitorious.MergeRequestController.getInstance();
        assertSame(firstController, secondController);
    },
    testNoReloadUnlessChanged: function() {
        var c = new Gitorious.MergeRequestController();
        c._setCurrentShaRange("ffac");
        c.shaSelected("ffac");
        assertFalse(c.needsUpdate());
        c._setCurrentVersion(2);
        c.versionSelected(2);
        assertFalse(c.needsUpdate());
        c.shaSelected("ffcc");
        assertTrue(c.needsUpdate());
    },
    testDetermineDefaultVersionAndSha: function(){
    },
    
    testFetchVersionUrl: function() {
        var c = Gitorious.MergeRequestController.getInstance();
        c.getBaseDiffUrl = function() {
            return "/gitorious/mainline/merge_requests/15/merge_request_versions/47";
        }
        c.versionSelected(2);
        //        assertEquals("", c.getDiffUrl());
        // No fetch
        c.versionSelected(3);
        //        assertEquals("", c.getDiffUrl());
        // Fetch
        // Notification when fetched to redisplay shas
        c._setTransport(jQuery);
    },

    testSelectDifferentVersion: function() {
        var c = Gitorious.MergeRequestController.getInstance();
        c._setCurrentShaRange("ffac");
        c._setCurrentVersion(2);

        var ControllerMock = function() {
            this.called = false;
            this.ajax = function(args){
                this.calledWith = args;
            };
            this.ajaxReceived = function() {
                NotificationCenter.notifyObservers("MergeRequestDiffReceived", this, ["data", "message"]);
            }
        };
        var m = new ControllerMock();

        c._setTransport(m);

        c.update({'version': 1, 'sha': 'ffcc-aa90888'});
        var callArgs = m.calledWith;
        assertEquals("ffcc-aa90888", callArgs.data.commit_shas);
        m.ajaxReceived();
        assertFalse(c.needsUpdate());    
    }
})