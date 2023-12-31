; usage: lingy fizzbuzz [<count>] [<fizzbuzz fn #>]

(defn run-a-fizzbuzz-implementation []
  (let [
    count (number (nth *command-line-args* 0 "100"))
    fizzbuzz (
      resolve (symbol (str "fizzbuzz-" (nth *command-line-args* 1 "1"))))
    result (fizzbuzz count)]
    (if (seq result)
      (map println result))))

(defn fizzbuzz-1 [n]
  (map
    (fn [x]
      (cond
        (zero? (mod x 15)) "FizzBuzz"
        (zero? (mod x 5)) "Buzz"
        (zero? (mod x 3)) "Fizz"
        :else x))
    (range 1 (inc n))))

(defn fizzbuzz-2 [n]
  (loop [i 1 l []]
    (if (<= i n)
      (recur (inc i) (conj l
        (cond
          (zero? (mod i 15)) "FizzBuzz"
          (zero? (mod i 5)) "Buzz"
          (zero? (mod i 3)) "Fizz"
          :else i)))
      l)))

(defn fizzbuzz-3 [n]
  (doseq [x (range 1 (inc n))]
    (println x
      (str
        (when (zero? (mod x 3)) "fizz")
        (when (zero? (mod x 5)) "buzz")))))

(run-a-fizzbuzz-implementation)
