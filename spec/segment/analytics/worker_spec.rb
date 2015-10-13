require 'spec_helper'

module Segment
  class Analytics
    describe Worker do
      describe "#init" do
        it 'accepts string keys' do
          queue = Queue.new
          worker = Segment::Analytics::Worker.new(queue, 'secret', 'batch_size' => 100)
          expect(worker.instance_variable_get(:@batch_size)).to eq(100)
        end
      end

      describe '#flush' do
        before :all do
          Segment::Analytics::Defaults::Request::BACKOFF = 0.1
        end

        after :all do
          Segment::Analytics::Defaults::Request::BACKOFF = 30.0
        end

        it 'should not error if the endpoint is unreachable' do
          expect(Net::HTTP::Post).to receive(:new).exactly(4).times.and_raise(Exception)

          queue = Queue.new
          queue << {}
          worker = Segment::Analytics::Worker.new(queue, 'secret')
          worker.run

          expect(queue).to be_empty
        end

        it 'should execute the error handler if the request is invalid' do
          expect_any_instance_of(Segment::Analytics::Request).to receive(:post).and_return(Segment::Analytics::Response.new(400, "Some error"))

          on_error = Proc.new do |status, error|
            puts "#{status}, #{error}"
          end

          expect(on_error).to receive(:call).once

          queue = Queue.new
          queue << {}
          worker = Segment::Analytics::Worker.new queue, 'secret', :on_error => on_error
          worker.run

          expect(queue).to be_empty
        end

        it 'should not call on_error if the request is good' do

          on_error = Proc.new do |status, error|
            puts "#{status}, #{error}"
          end

          expect(on_error).not_to receive(:call)

          queue = Queue.new
          queue << Requested::TRACK
          worker = Segment::Analytics::Worker.new queue, 'testsecret', :on_error => on_error
          worker.run

          expect(queue).to be_empty
        end
      end

      describe '#is_requesting?' do
        it 'should not return true if there isn\'t a current batch' do
          queue = Queue.new
          worker = Segment::Analytics::Worker.new(queue, 'testsecret')

          expect(worker.is_requesting?).to eq(false)
        end

        it 'should return true if there is a current batch' do
          queue = Queue.new
          queue << Requested::TRACK
          worker = Segment::Analytics::Worker.new(queue, 'testsecret')

          Thread.new do
            worker.run
            expect(worker.is_requesting?).to eq(false)
          end

          eventually { expect(worker.is_requesting?).to eq(true) }
        end
      end
    end
  end
end
