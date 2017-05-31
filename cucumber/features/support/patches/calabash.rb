module Calabash
  module Cucumber
    module Core
       def clear_text_in_first_responder
         response = http({method: :get, path: "clearText"}, {})
         hash = JSON.parse(response)
         if hash["outcome"] != "SUCCESS"
           message = %Q[
http GET /clearText failed for:

 reason: #{hash["reason"]}
details: #{hash["details"]}
]

           screenshot_and_raise(message)
         end
         hash
       end
    end
  end
end
