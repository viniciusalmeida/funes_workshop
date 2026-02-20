#!/usr/bin/env bb

(require '[babashka.http-client :as http]
         '[cheshire.core :as json])

(def base-url (or (first *command-line-args*) "http://localhost:3000"))
(def api-url (str base-url "/api"))

(defn create-debt [{:keys [principal interest-rate at]}]
  (let [resp (http/post (str api-url "/debts")
               {:headers {"Content-Type" "application/json"}
                :body (json/generate-string
                        {:debt {:principal principal
                                :interest_rate interest-rate
                                :interest_rate_base "yearly"
                                :at at}})})]
    (json/parse-string (:body resp) true)))

(defn get-debt [idx]
  (let [resp (http/get (str api-url "/debts/" idx))]
    (json/parse-string (:body resp) true)))

(defn create-payment [idx {:keys [amount at]}]
  (let [resp (http/post (str api-url "/debts/" idx "/payments")
               {:headers {"Content-Type" "application/json"}
                :body (json/generate-string
                        {:payment {:amount amount :at at}})})]
    (json/parse-string (:body resp) true)))

(defn print-debt [label debt]
  (println (format "  %-30s idx=%-10s principal=%-12s present_value=%-12s interest_rate=%s contract_date=%s last_payment_at=%s"
                   label
                   (:idx debt)
                   (:principal debt)
                   (:present_value debt)
                   (:interest_rate debt)
                   (:contract_date debt)
                   (:last_payment_at debt))))

;; Case 1: Interest accrual without payment
;; $10,000 principal, 10% annual, no payments
(println "\n=== Case 1: Interest accrual without payment ===")
(let [debt (create-debt {:principal 10000 :interest-rate 0.1 :at "2025-01-01"})]
  (print-debt "Created" debt)
  (print-debt "State (no payments)" (get-debt (:idx debt))))

;; Case 2: Interest accrual with payment
;; $10,000 principal, 10% annual, $5,000 payment on 2025-07-01
(println "\n=== Case 2: Interest accrual with payment ===")
(let [debt    (create-debt {:principal 10000 :interest-rate 0.1 :at "2025-01-01"})
      _       (print-debt "Created" debt)
      after   (create-payment (:idx debt) {:amount 5000 :at "2025-07-01"})]
  (print-debt "After $5,000 payment" after)
  (print-debt "Current state" (get-debt (:idx debt))))

;; Case 3: Interest accrual with payment and final repayment
;; $10,000 principal, 10% annual, $5,000 on 2025-07-01, $5,772.94 on 2026-01-01
(println "\n=== Case 3: Interest accrual with payment and final repayment ===")
(let [debt    (create-debt {:principal 10000 :interest-rate 0.1 :at "2025-01-01"})
      _       (print-debt "Created" debt)
      after1  (create-payment (:idx debt) {:amount 5000 :at "2025-07-01"})
      _       (print-debt "After 1st payment ($5,000)" after1)
      after2  (create-payment (:idx debt) {:amount 5772.94 :at "2026-01-01"})]
  (print-debt "After 2nd payment ($5,772.94)" after2)
  (print-debt "Final state" (get-debt (:idx debt))))

(println)
