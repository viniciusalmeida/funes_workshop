require "test_helper"

# Money#as_json is overridden globally to a cents/currency pair for the event store, so the API's
# decimal contract only holds because Api::BaseController unwraps it. These tests pin that contract.
class Api::DebtsControllerTest < ActionDispatch::IntegrationTest
  describe "POST create" do
    test "renders monetary values as plain decimals" do
      post api_debts_url, params: { debt: { principal: 1000, interest_rate: 0.10, at: Date.current } }, as: :json
      body = response.parsed_body

      assert_response :created
      assert_equal "1000.0", body["principal"],
                   "the public API predates money-rails and must not leak the cents/currency shape"
      assert_equal "1000.0", body["present_value"], "no interest has accrued on the day of issuance"
    end

    test "renders validation errors for a non-positive principal" do
      post api_debts_url, params: { debt: { principal: 0, interest_rate: 0.10, at: Date.current } }, as: :json

      assert_response :unprocessable_entity
      assert_includes response.parsed_body["errors"], "Principal must be greater than 0"
    end
  end

  describe "GET show" do
    test "renders the accrued present value as a plain decimal" do
      DebtEventStream.for("api-0001").append(Debt::Issued.new(principal: 10000, interest_rate: 0.10,
                                                              at: Date.current - 365))

      get api_debt_url("api-0001")
      body = response.parsed_body

      assert_response :success
      assert_equal "10000.0", body["principal"]
      assert_equal "11000.0", body["present_value"], "a full year of 10% simple interest on $10,000"
    end
  end
end
