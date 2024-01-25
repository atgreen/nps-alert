(dolist (pkg '(:cl-json :sqlite :drakma :flexi-streams))
  (asdf:load-system pkg))

(handler-case
    (sqlite:with-open-database (db "aon.db")
      (sqlite:execute-non-query db "create table if not exists nps_alerts (alert_id text not null primary key)")
      (let ((data
              (cdr (assoc :DATA (json:decode-json-from-string
                                 (flexi-streams:octets-to-string
                                  (drakma:http-request (format nil "https://developer.nps.gov/api/v1/alerts?parkCode=zion&api_key=~A" (uiop:getenv "NPS_API_KEY"))
                                                       :method :get)))))))
        (dolist (alert data)
          (let ((id (cdr (assoc :ID alert))))
            (unless (sqlite:execute-single db
                                           (format nil "select alert_id from nps_alerts where alert_id = '~A';" id))
              (sqlite:execute-single db
                                     (format nil "insert into nps_alerts (alert_id) values ('~A');" id))
              (format t "NPS Alert::~A::~A::~A~%"
                      (cdr (assoc :TITLE alert))
                      (cdr (assoc :DESCRIPTION alert))
                      (cdr (assoc :URL alert))))))))
  (error (e)
    (format t "error in nps-check: ~A~%" e)))

(sb-ext:quit)
