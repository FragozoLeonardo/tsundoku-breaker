# frozen_string_literal: true

FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    sequence(:isbn) { |n| "9780132350#{format('%03d', n)}" }

    trait :reading do
      status { :reading }
    end

    trait :finished do
      status { :finished }
    end

    trait :invalid do
      title { nil }
    end
  end
end
